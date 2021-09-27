// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SuperShibaClub is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SHIBAS = 10010;
    uint256 public constant MAX_MINT = 5;
    uint256 public constant MAX_EARLY_MINT = 2;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant RESERVED = 200;
    
    uint256 private reservedMinted;
    address public superShibaClubTreasury;
    string private baseTokenURI;
    bool public isRevealed;
    
    IERC721 private bssc;
    bool public isBsscSalesActive = false; // BSSC
    mapping(uint256 => bool) private bsscRedeemed;

    bool public isWhitelistSalesActive = false; // Whitelist
    mapping(address => uint256) private whitelistSales;
    mapping(address => bool) private whitelistedMap;

    bool public isPublicSalesActive = false;

    constructor(address _treasury, address _bssc) ERC721("Super Shiba Club", "SSC") {
        superShibaClubTreasury = _treasury;
        bssc = IERC721(_bssc);
    }
    
    function treasuryReserve() public onlyOwner {        
        uint supply = totalSupply();
        uint maxPerTx = 50;
        require(reservedMinted < RESERVED, "Reserved fully minted");
        require(supply.add(maxPerTx) <= MAX_SHIBAS.sub(RESERVED).add(reservedMinted), "Fully minted");
        for (uint256 i; i < maxPerTx; i++) {
            _safeMint(superShibaClubTreasury, supply + i);
        }
        reservedMinted = reservedMinted.add(maxPerTx);
    }
    
    function bsscMint(uint256[] calldata ids) public {
        require(isBsscSalesActive, "BAMC x Super Shiba Club sales not active");
        uint256 supply = totalSupply();
        require(supply.add(ids.length) <= MAX_SHIBAS.sub(RESERVED).add(reservedMinted), "Fully minted");
        
        for (uint256 i; i < ids.length; i++) {
            require(bsscRedeemed[ids[i]] == false, "Token already redeemed!");
            require(bssc.ownerOf(ids[i]) == msg.sender, "Token owner only");
            _safeMint(msg.sender, supply + i);
            bsscRedeemed[ids[i]] = true;
        }
    }
    
    function isBsscRedeemed(uint256 bsscId) public view returns (bool){
        require(bssc.ownerOf(bsscId) != address(0), "Token not exist");
        return bsscRedeemed[bsscId];
    }

    function whitelistMint(uint256 num) public payable {
        require(isWhitelistSalesActive, "Whitelist sales not active");
        (bool isWhitelist, bool isBssc, uint256 minted) = isWhitelisted(msg.sender);
        require(isWhitelist || isBssc, "Not whitelisted");
        uint256 max;
        if(isWhitelist || isBssc){
            max = MAX_EARLY_MINT;
            if(minted > 0 && minted <= MAX_EARLY_MINT){
                max = max.sub(minted);
            }
            if(isWhitelist && isBssc){
                max = MAX_EARLY_MINT.add(MAX_EARLY_MINT).sub(minted);
            }
        }
        require(
            num <= max,
            "Reached max, wait for public sales"
        );
        uint256 supply = totalSupply();
        require(supply.add(num) <= MAX_SHIBAS.sub(RESERVED).add(reservedMinted), "Fully minted");
        require(msg.value >= num * PRICE, "Invalid price");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
        whitelistSales[msg.sender] = whitelistSales[msg.sender].add(num);
    }

    function isWhitelisted(address _address) public view returns (bool, bool, uint256) {
        return (whitelistedMap[_address], bssc.balanceOf(_address) > 0, whitelistSales[_address]);
    }

    function publicMint(uint256 num) public payable {
        require(isPublicSalesActive, "Public sales not active");
        uint256 supply = totalSupply();
        require(num <= MAX_MINT, "Reached max per transaction");
        require(supply.add(num) <= MAX_SHIBAS.sub(RESERVED).add(reservedMinted), "Fully minted");
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

    function setSalesState(bool _bssc, bool _whitelist, bool _public) external onlyOwner {
        isBsscSalesActive = _bssc;
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