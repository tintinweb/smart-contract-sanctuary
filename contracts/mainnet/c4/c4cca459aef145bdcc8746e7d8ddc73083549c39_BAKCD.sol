// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BAKCD is ERC721Enumerable, Ownable {

    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant MINT_PER_TX = 5;
    uint256 public constant MAX_FREE_MINT = 1;
    uint256 public constant PRICE = 0.069 ether;
    address public treasury;
    string private baseTokenURI;
    bool public publicActive;
    bool public freeMintActive;
    mapping(address => uint256) private freeMints;
    mapping(address => bool) private whitelistedAddr;
    IERC721 public bamc48h;
    bool public bamc48hActive;
    mapping(uint256 => bool) private bamc48hMinted;

    constructor(address _treasury, address _bamc48h) ERC721("BAMC x AK Cyber Dolphin", "BAKCD") {
        treasury = _treasury;
        bamc48h = IERC721(_bamc48h);
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

    function freeMint() public {
        require(freeMintActive, "Whitelist not open");
        (bool isWhitelist, uint256 mints) = isWhitelisted(msg.sender);
        require(isWhitelist, "Not whitelisted");
        require(mints < MAX_FREE_MINT, "Exceed limit");
        uint256 supply = totalSupply();
        require(supply + MAX_FREE_MINT < MAX_SUPPLY, "Sold out");

        _safeMint(msg.sender, supply);
        freeMints[msg.sender] = MAX_FREE_MINT;
    }

    function bamc48hMint(uint256[] calldata _ids) public {
        require(bamc48hActive, "BAMC x AK Cyber Dolphin not open");
        uint256 supply = totalSupply();
        require(supply + _ids.length <= MAX_SUPPLY, "Sold out");
        
        for (uint256 i; i < _ids.length; i++) {
            require(bamc48hMinted[_ids[i]] == false, "Token minted");
            require(bamc48h.ownerOf(_ids[i]) == msg.sender, "Not owner");
            _safeMint(msg.sender, supply + i);
            bamc48hMinted[_ids[i]] = true;
        }
    }

    function isBamc48hMinted(uint256 _bamc48h) public view returns (bool){
        require(bamc48h.ownerOf(_bamc48h) != address(0), "Token not exist");
        return bamc48hMinted[_bamc48h];
    }

    function isWhitelisted(address _address) public view returns (bool, uint256) {
        return (whitelistedAddr[_address], freeMints[_address]);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function updateSales(bool _public, bool _freeMint, bool _bamc48h) external onlyOwner {
        publicActive = _public;
        freeMintActive = _freeMint;
        bamc48hActive = _bamc48h;
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