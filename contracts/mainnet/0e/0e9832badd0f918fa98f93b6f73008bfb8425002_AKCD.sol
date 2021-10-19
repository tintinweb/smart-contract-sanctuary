// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract AKCD is ERC721Enumerable, Ownable {

    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MINT_PER_TX = 5;
    uint256 public constant MAX_PREMINT = 4;
    uint256 public constant PRICE = 0.069 ether;
    address public treasury;
    string private baseTokenURI;
    bool public publicActive;
    bool public whitelistActive;
    mapping(address => uint256) private whitelistMints;
    mapping(address => bool) private whitelistedAddr;
    IERC721 public bakcd;
    bool public bakcdActive;
    mapping(uint256 => bool) private bakcdMinted;

    constructor(address _treasury, address _bakcd) ERC721("AK Cyber Dolphin", "AKCD") {
        treasury = _treasury;
        bakcd = IERC721(_bakcd);
    }

    function publicMint(uint256 num) public payable {
        require(publicActive, "Public not open");
        require(num <= MINT_PER_TX, "Reach max per tx");
        uint256 supply = totalSupply();
        require(supply + num <= MAX_SUPPLY, "Sold out");
        require(msg.value >= num * PRICE, "Invalid payment");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function whitelistMint(uint256 num) public payable {
        require(whitelistActive, "Whitelist not open");
        (bool isWhitelist, bool isBakcd, uint256 mints) = isWhitelisted(msg.sender);
        require(isWhitelist || isBakcd, "Not whitelisted");
        uint256 max;
        if(isWhitelist || isBakcd){
            max = MAX_PREMINT;
            if(mints > 0 && mints <= MAX_PREMINT){
                max = max - mints;
            }
            if(isWhitelist && isBakcd){
                max = MAX_PREMINT + MAX_PREMINT - mints;
            }
        }
        require(num <= max, "Reach max for whitelist");
        uint256 supply = totalSupply();
        require(supply + num < MAX_SUPPLY, "Sold out");
        require(msg.value >= num * PRICE, "Invalid payment");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
        whitelistMints[msg.sender] = whitelistMints[msg.sender] + num;
    }

    function isWhitelisted(address _address) public view returns (bool, bool, uint256) {
        return (whitelistedAddr[_address], bakcd.balanceOf(_address) > 0, whitelistMints[_address]);
    }

    function bakcdMint(uint256[] calldata _ids) public {
        require(bakcdActive, "BAMC x AK Cyber Dolphin not open");
        uint256 supply = totalSupply();
        require(supply + _ids.length <= MAX_SUPPLY, "Sold out");
        
        for (uint256 i; i < _ids.length; i++) {
            require(bakcdMinted[_ids[i]] == false, "Token minted");
            require(bakcd.ownerOf(_ids[i]) == msg.sender, "Not owner");
            _safeMint(msg.sender, supply + i);
            bakcdMinted[_ids[i]] = true;
        }
    }

    function isBakcdMinted(uint256 _bakcd) public view returns (bool){
        require(bakcd.ownerOf(_bakcd) != address(0), "Token not exist");
        return bakcdMinted[_bakcd];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function updateSales(bool _public, bool _whitelist, bool _bakcd) external onlyOwner {
        publicActive = _public;
        whitelistActive = _whitelist;
        bakcdActive = _bakcd;
    }

    function insertWhitelist(address[] calldata _address) public onlyOwner {
        for (uint256 i; i < _address.length; i++) {
            whitelistedAddr[_address[i]] = true;
        }
    }

    function removeWhitelist(address[] calldata _address) public onlyOwner {
        for (uint256 i; i < _address.length; i++) {
            whitelistedAddr[_address[i]] = false;
        }
    }
    
    function withdraw() public onlyOwner {
        payable(treasury).transfer(address(this).balance);
    }
}