// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SuperShibaBAMC is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SHIBAS = 333;
    uint256 public constant MAX_MINT = 2;
    uint256 public constant MAX_EARLY_MINT = 1;
    uint256 public constant PRICE = 0.05 ether;
    
    address private superShibaClubTreasury;
    string private baseTokenURI;
    bool public isRevealed;

    bool public isWhitelistSalesActive = false; // Whitelist
    mapping(address => uint256) private whitelistSales;
    mapping(address => bool) private whitelistedMap;

    bool public isPublicSalesActive = false;


    constructor(address _treasury) ERC721("BAMC x Super Shiba Club", "BSSC") {
        superShibaClubTreasury = _treasury;
    }
    
    function whitelistMint() public {
        require(isWhitelistSalesActive, "Whitelist sales not active");
        (bool isWhitelist, ) = isWhitelisted(msg.sender);
        require(isWhitelist, "Not whitelisted, wait for public sales");
        require(
            whitelistSales[msg.sender] < MAX_EARLY_MINT,
            "Reached max, wait for public sales"
        );
        uint256 supply = totalSupply();
        require(supply.add(1) <= MAX_SHIBAS, "Fully minted");
        
        _safeMint(msg.sender, supply);
        whitelistSales[msg.sender] = 1;
    }

    function getWhitelistBalance(address _address) public view returns (uint256) {
        (bool isWhitelist, ) = isWhitelisted(_address);
        require(isWhitelist, "Not whitelisted");
        return MAX_EARLY_MINT.sub(whitelistSales[_address]);
    }

    function isWhitelisted(address _address) public view returns (bool, bool) {
        return (whitelistedMap[_address], isWhitelistSalesActive);
    }

    function publicMint(uint256 num) public payable {
        require(isPublicSalesActive, "Public sales not active");
        require(num <= MAX_MINT, "Reached max per transaction");
        uint256 supply = totalSupply();
        require(supply.add(num) <= MAX_SHIBAS, "Fully minted");
        require(msg.value >= num * PRICE, "Invalid price");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    
    function withdraw() public onlyOwner {
        payable(superShibaClubTreasury).transfer(address(this).balance);
    }

    function setSalesState(bool _whitelist, bool _public) external onlyOwner {
        isWhitelistSalesActive = _whitelist;
        isPublicSalesActive = _public;
    }

    function addWhitelist(address[] calldata _address) public onlyOwner {
        for(uint i = 0; i < _address.length; i++){
            whitelistedMap[_address[i]] = true;
        }
    }

    function removeWhitelist(address[] calldata _address) public onlyOwner {
        for(uint i = 0; i < _address.length; i++){
            whitelistedMap[_address[i]] = false;
        }
    }

    function changeRevealed() public onlyOwner {
        isRevealed = !isRevealed;
    }
}